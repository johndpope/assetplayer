import Nimble
import Quick

class ExampleSpec: QuickSpec {
    override func spec() {
        describe("basic test") {
            it("should eval true") {
                let myBool = true
                expect(myBool).to(beTrue())
            }
        }
    }
}
